"use client";

import { useRouter } from "next/navigation";
import type { NextPage } from "next";

interface Competition {
  id: string;
  title: string;
  participants: number;
  startDate: Date;
  endDate: Date;
}

const Home: NextPage = () => {
  const router = useRouter();

  const competitions: Competition[] = [
    {
      id: '1',
      title: 'Summer Trading Championship',
      participants: 1234,
      startDate: new Date('2025-06-01'),
      endDate: new Date('2025-08-31'),
    },
    {
      id: '2',
      title: 'Crypto Prediction Challenge',
      participants: 856,
      startDate: new Date('2025-03-15'),
      endDate: new Date('2025-04-15'),
    },
    {
      id: '3',
      title: 'Winter Trading Contest',
      participants: 2145,
      startDate: new Date('2024-12-01'),
      endDate: new Date('2025-01-31'),
    },
    {
      id: '4',
      title: 'Spring Forex Championship',
      participants: 1567,
      startDate: new Date('2024-04-01'),
      endDate: new Date('2024-05-31'),
    },
  ];

  const now = new Date();
  const upcomingCompetitions = competitions.filter(comp => comp.startDate > now);
  const pastCompetitions = competitions.filter(comp => comp.endDate < now);

  const CompetitionCard = ({ competition, isPast }: { competition: Competition; isPast: boolean }) => (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="font-medium text-lg text-gray-900">{competition.title}</h3>
          <div className="mt-1 text-sm text-gray-500">
            {competition.startDate.toLocaleDateString()} - {competition.endDate.toLocaleDateString()}
          </div>
        </div>
        <div className="flex items-center gap-1">
          <div className="text-sm font-medium text-gray-900">{competition.participants.toLocaleString()}</div>
          <div className="text-sm text-gray-500">participants</div>
        </div>
      </div>
      
      <div className="flex gap-2">
        {isPast ? (
          <>
            <button className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 transition-colors">
              View Results
            </button>
            <button className="flex-1 px-4 py-2 bg-blue-50 text-blue-700 rounded-md hover:bg-blue-100 transition-colors">
              View Analysis
            </button>
          </>
        ) : (
          <>
            <button onClick={() => router.push("/predicting")} className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors">
              Join Competition
            </button>
            <button className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 transition-colors">
              Learn More
            </button>
          </>
        )}
      </div>
    </div>
  );

  return (
<div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-2xl font-bold text-gray-900 mb-8">Competitions Dashboard</h1>
        
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-900">Upcoming Competitions</h2>
            <div className="text-sm text-gray-500">{upcomingCompetitions.length} competitions</div>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            {upcomingCompetitions.map(competition => (
              <CompetitionCard key={competition.id} competition={competition} isPast={false} />
            ))}
            {upcomingCompetitions.length === 0 && (
              <div className="col-span-2 text-center py-8 text-gray-500">
                No upcoming competitions at the moment
              </div>
            )}
          </div>
        </div>
        
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-900">Past Competitions</h2>
            <div className="text-sm text-gray-500">{pastCompetitions.length} competitions</div>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            {pastCompetitions.map(competition => (
              <CompetitionCard key={competition.id} competition={competition} isPast={true} />
            ))}
            {pastCompetitions.length === 0 && (
              <div className="col-span-2 text-center py-8 text-gray-500">
                No past competitions
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
